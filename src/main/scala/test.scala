import scala.math._

class SomeCentralClass {

  def loadItems(clientCode: String) = {
    Thread sleep (random * 1000).toLong + 50
    List(clientCode +"-item1", clientCode + "-item2")
  }
}

class Client(name: String, sleeptime: Int, scc: SomeCentralClass) extends Runnable {
  override def run(): Unit = {

    println(name + " started")

    for (i <- 0 to 1000)
    yield {
      println(name + ":" + scc.loadItems(name))

      //Sleep for more or less 20% of the sleeptime
      val timetowait = (random * sleeptime * 0.4 + sleeptime * 0.8).toLong
      println(name + " sleeping for " + timetowait / 1000.0 / 60 + "m")
      Thread sleep (timetowait)
    }
  }
}

object Test {

  def main (args: Array[String]) {

    val scc = new SomeCentralClass

    startClient("C1", 60, scc) //Once per hour
    startClient("C2", 80, scc) //Less than once per hour
    startClient("C3", 50, scc) //Twice per hour
    startClient("C4", 10, scc) //Once in 10 minutes
    startClient("C5", 5, scc) //Every 5 minutes
    startClient("C6", 1, scc) //Every minute

  }

  private def startClient(name: String, sleepMinutes: Int, scc: SomeCentralClass): Unit = {
    (new Thread(new Client(name, sleepMinutes * 60 * 1000, scc))) start
  }

}